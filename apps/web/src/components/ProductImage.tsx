interface ProductImageProps {
  src: string | null;
  alt: string;
  className?: string;
}

export function ProductImage({ src, alt, className = '' }: ProductImageProps) {
  return (
    <div className={`overflow-hidden rounded-xl bg-stone-100 ${className}`}>
      {src ? (
        // Las URLs las cargan administradores desde cualquier dominio; next/image
        // obligaría a declarar cada dominio en next.config.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt={alt} loading="lazy" className="h-full w-full object-cover" />
      ) : (
        <div
          aria-hidden
          className="flex h-full w-full items-center justify-center text-3xl text-stone-300"
        >
          🛒
        </div>
      )}
    </div>
  );
}
